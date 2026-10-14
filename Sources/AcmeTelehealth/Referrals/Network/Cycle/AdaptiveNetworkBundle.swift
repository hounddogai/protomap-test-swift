import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network bundle is in its life cycle.
    enum AdaptiveNetworkBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive network bundle, with what the planners need to act on it.
    final class AdaptiveNetworkBundle {
        var code: String
        var title: String
        var reviewer: String
        var description: String
        var refills: Int
        var updatedAt: Int
        var summary: String
        var expiresAt: Int
        var dosageMg: Double
        var revision: Int
        var phone: String
        var status: AdaptiveNetworkBundleStatus

        init(code: String, title: String, reviewer: String, description: String, refills: Int, updatedAt: Int, summary: String, expiresAt: Int, dosageMg: Double, revision: Int, phone: String, status: AdaptiveNetworkBundleStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.description = description
            self.refills = refills
            self.updatedAt = updatedAt
            self.summary = summary
            self.expiresAt = expiresAt
            self.dosageMg = dosageMg
            self.revision = revision
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveNetworkBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveNetworkBundleStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AdaptiveNetworkBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveNetworkBundle {
            return AdaptiveNetworkBundle(
                code: code,
                title: title,
                reviewer: reviewer,
                description: description,
                refills: refills,
                updatedAt: updatedAt,
                summary: summary,
                expiresAt: expiresAt,
                dosageMg: dosageMg,
                revision: revision,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive network bundle in status idle.
    static func newAdaptiveNetworkBundle(_ code: String, title: String) -> AdaptiveNetworkBundle {
        return AdaptiveNetworkBundle(
            code: code,
            title: title,
            reviewer: "",
            description: "",
            refills: 0,
            updatedAt: 0,
            summary: "",
            expiresAt: 0,
            dosageMg: 0.0,
            revision: 0,
            phone: "",
            status: AdaptiveNetworkBundleStatus.idle
        )
    }
}
