import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional witness draft is in its life cycle.
    enum RegionalWitnessDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional witness draft, with what the planners need to act on it.
    final class RegionalWitnessDraft {
        var code: String
        var label: String
        var endsAt: Int
        var cost: Double
        var batchSize: Int
        var revision: Int
        var limit: Int
        var status: RegionalWitnessDraftStatus

        init(code: String, label: String, endsAt: Int, cost: Double, batchSize: Int, revision: Int, limit: Int, status: RegionalWitnessDraftStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.cost = cost
            self.batchSize = batchSize
            self.revision = revision
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalWitnessDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalWitnessDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional witness draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((Double(endsAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalWitnessDraft {
            return RegionalWitnessDraft(
                code: code,
                label: label,
                endsAt: endsAt,
                cost: cost,
                batchSize: batchSize,
                revision: revision,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional witness draft in status requested.
    static func newRegionalWitnessDraft(_ code: String, label: String) -> RegionalWitnessDraft {
        return RegionalWitnessDraft(
            code: code,
            label: label,
            endsAt: 0,
            cost: 0.0,
            batchSize: 0,
            revision: 0,
            limit: 0,
            status: RegionalWitnessDraftStatus.requested
        )
    }
}
