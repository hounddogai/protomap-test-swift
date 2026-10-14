import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional network bundle is in its life cycle.
    enum RegionalNetworkBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional network bundle, with what the planners need to act on it.
    final class RegionalNetworkBundle {
        var code: String
        var label: String
        var encounterID: String
        var refills: Int
        var procedureCode: String
        var externalRef: String
        var category: String
        var summary: String
        var score: Double
        var status: RegionalNetworkBundleStatus

        init(code: String, label: String, encounterID: String, refills: Int, procedureCode: String, externalRef: String, category: String, summary: String, score: Double, status: RegionalNetworkBundleStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.refills = refills
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.category = category
            self.summary = summary
            self.score = score
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

        func canMoveTo(_ next: RegionalNetworkBundleStatus) -> Bool {
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
                return next == RegionalNetworkBundleStatus.expired
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

        func moveTo(_ next: RegionalNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional network bundle") \(code)"
        }

        func weightedLoad() -> Double {
            return (score * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> RegionalNetworkBundle {
            return RegionalNetworkBundle(
                code: code,
                label: label,
                encounterID: encounterID,
                refills: refills,
                procedureCode: procedureCode,
                externalRef: externalRef,
                category: category,
                summary: summary,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional network bundle in status requested.
    static func newRegionalNetworkBundle(_ code: String, label: String) -> RegionalNetworkBundle {
        return RegionalNetworkBundle(
            code: code,
            label: label,
            encounterID: "",
            refills: 0,
            procedureCode: "",
            externalRef: "",
            category: "",
            summary: "",
            score: 0.0,
            status: RegionalNetworkBundleStatus.requested
        )
    }
}
