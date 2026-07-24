# My k8s-native Homelab

> My best attempt at pretending to be a DevOps Engineer. Welcome to my learning environment. This is a sanitized public mirror of my homelab's IaC repo.

## Background

I've been homelabbing for years. This latest stack is where all of it was always headed: I got tired of clicking through UIs to configure things by hand, and started wondering if there was a better way. Found k8s, discovered the tooling built around it, and never looked back. The rest is git commit history. 


## Architecture

*(Diagrams coming soon. Need to create network topology overview and trust-tier diagrams.)*


## Lessons Learned

There are so many sharp edges one encounters when building Kubernetes clusters and hosting real applications on them. It's a humbling process. As you add more features, apps, and security controls, complexity explodes. I broke the PKI a dozen times. Connecting Authentik and Kanidm was a multi-day endeavor. And if my power goes out right now, I need to manually unseal Vault. Being a one-man security, platform, and infra team is a lot of hats, and I've broken something under most of them.

**Greatest hits from the incident log:**

**a. Four letters, two days:** Security Onion's Suricata container expects packet capture output at /nsm/suripcap; I mounted my NFS share at /nsm/pcap. Four letters was the difference between writing to the 4TB pool on TrueNAS and writing to local disk instead. The local directory was writable, so I got no errors. I only caught it by checking actual usage on the NFS export. Lesson: absence of failure isn't presence of success. Also, double check the docs.

**b. The endpoint IP that couldn't exist yet:** CAPMOX won't let a cluster's controlPlaneEndpoint overlap its IP pool. This makes sense, until you're trying to bootstrap a brand-new single-node cluster and the only node is the pool. The fix is a Talos VIP, which lets one node hold both its pool IP and the fixed endpoint IP at once... except the VIP doesn't activate until etcd is already up. This means you can't point talosconfig at it during bootstrap either. Zero information online to dig me out of this one. After much head-scratching and trial-and-error, I worked out the solution. Bootstrap against the node's pool IP directly, wait for etcd come up, then let the VIP take over as the real endpoint once it's healthy.

**c. The policy that looked fine but wasn't:** Locking down Crossplane's namespace with a default-deny Cilium NetworkPolicy immediately disconnected it from the k8s API. Cilium doesn't support combining toServices and toPorts in the same rule, which isn't documented anywhere in the CRD schema. I had to use toEntities: [kube-apiserver], which fixed it. Well... except on Talos. K8s API traffic routed through KubePrism shows up in Cilium as the host, not kube-apiserver, so I needed a second rule just for that. I ultimately figured out my blunder with hubble observe, which let me see dropped traffic in real time. 


## Technology Stack

#### Infrastructure Layer
| Component | Tool | Notes |
|---|---|---|
| Hypervisor | Proxmox VE | Runs all clusters, VMs, and OOB infra |
| Node OS | Talos Linux | Chosen specifically to minimize node attack surface |
| Storage | TrueNAS SCALE | democratic-csi (iSCSI + NFS), Fibre Channel HBA and disk shelves |
| Networking | OPNsense | Virtual, VLAN segmentation; sits behind a physical upstream firewall |

#### Kubernetes Platform
| Component | Tool | Notes |
|---|---|---|
| CNI | Cilium | BGP-advertised LoadBalancer IPs; also enforces namespace-level network policy |
| GitOps | ArgoCD | App-of-apps pattern; Hub-managed sync to Spoke and Apps clusters |
| Secrets | HashiCorp Vault | VCO for declarative Vault config, VSO for syncing secrets into pods |
| PKI | HashiCorp Vault (intermediate CA) | cert-manager for issuance, trust-manager for CA bundle distribution |
| Policy | Kyverno | Admission control for pod security standards |

#### Identity & Access
| Component | Tool | Notes |
|---|---|---|
| Identity Provider | Kanidm | OOB VM, source of truth for all identity, survives cluster loss |
| SSO | Authentik | Federated upstream to Kanidm via OIDC; SSO + MFA for ArgoCD, Harbor, Grafana, and more |
| Container Registry | Harbor | OIDC-gated, Spoke workloads migrating off direct internet pulls |

#### Observability
| Component | Tool | Notes |
|---|---|---|
| Monitoring | Prometheus + Grafana | Hub Prometheus remote-writes to Spoke for unified dashboards |
| Logging | Loki | Simple Scalable mode, self-hosted Garage S3 backend writing to TrueNAS |
| Log shipping | Alloy | DaemonSet ships pod logs from every node to Loki |

#### Security Operations
| Component | Tool | Notes |
|---|---|---|
| SOC | Security Onion | Standalone VM, separated from monitored clusters Suricata IDS, Zeek, full PCAP to a dedicated, encrypted, TrueNAS pool |
| Endpoint | Elastic Agent | Fleet-managed DaemonSet on every node for host visibility, FIM, Elastic Defend malware detection |
| Runtime enforcement | Tetragon | Process lineage, block/kill on policy match (in-progress) |
| Runtime detection | Falco | Feeds Security Onion for alerting, complements Tetragon's enforcement (in-progress) |

#### CI/CD
| Component | Tool | Status |
|---|---|---|
| CI Platform | GitHub Actions | Triggers on push to the Astro repo |
| Runners | Actions Runner Controller (ARC) | In-cluster, builds and pushes the Astro/nginx image to Harbor |
| Deployment | ArgoCD | Syncs the built image to the Apps cluster |
| Supply chain security | Cosign, Syft, Trivy/Grype,| Enforced at admission: signed, scanned, SBOM-attested images only (Planned) | 

---


## Roadmap / Current Status

### Complete
- Core networking & GitOps foundation (Talos, Cilium, BGP, ArgoCD, internal PKI)
- Hub/Spoke/Apps multi-cluster architecture (CAPI / CAPT-managed)
- Identity federation (Kanidm + Authentik OIDC and SSO)
- Secrets management (Vault, VCO, VSO)
- Full observability stack (kube-prometheus-stack, Loki, Alloy, Grafana)
- Security Onion SOC: real detection proven end-to-end with tmNIDS, plus baseline silence rules tuned to filter legitimate inter-cluster traffic
- Tetragon deployed on Hub and Spoke: eBPF observability confirmed
- Astro blog CI/CD pipeline (ARC build leads to ArgoCD deploy)

### In progress
- Harbor: deployed with OIDC and service accounts, but Spoke workloads still aren't fully routed through it (some still pull directly from the internet)
- Kyverno: baseline audit policies live (run-as-non-root, resource limits, host namespace blocking). Additional targeted policies  still being phased in.
- Tetragon: deployed, real eBPF events confirmed, but no actual TracingPolicy enforcement/detection rules written yet. Currently observation-only mode.
- Cilium network policies: pattern established, applied to a selection of namespaces so far.
- Connecting SIGMA rules and Elastic Defend: detections work in Kibana natively, but I'm working on an issue where custom SIGMA rules aren't displaying in Security Onion's own Detections view; still investigating!
- Secure cluster: for workloads holding genuinely sensitive personal data. 

### Planned
- Falco exporting logs to Security Onion, complementing Tetragon enforcement rules.
- Software supply chain security: image signing w/ Cosign, Syft SBOM, Trivy/Grype vuln scanning
- Disaster recovery: Velero backups + a tested Vault DR drill. On hold due to resource constraints.


## FAQ

**Can I just clone this and run it?**
Certainly not as-is. This is a frozen and heavity redacted snapshot of my environment. Domains, IPs, VLANs, secrets, and hardware assumptions are all specific to my environment. Some files are missing entirely. You'd need to customize essentially everything and piece together the gaps. I wouldn't recommend it.

**Why so much complexity for a homelab?**
The complexity is the point. This is how I learn how enterprise platform and security teams reason about trust boundaries, blast radius, and failure domains. 

**Is this actually running 24/7?**
Yes! Please don't ask about my power bill.

**Can I hire you?**
Yes! I'm actively looking for DevSecOps, DevOps, platform engineering, and security operations roles. Find me on [LinkedIn](https://www.linkedin.com/in/dylan-gollinger).