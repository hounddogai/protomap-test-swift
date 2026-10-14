import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal interaction agreement is in its life cycle.
    enum SeasonalInteractionAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal interaction agreement as the interaction team keeps it.
    final class SeasonalInteractionAgreement {
        var code: String
        var label: String
        var limit: Int
        var name: String
        var floorValue: Double
        var status: SeasonalInteractionAgreementStatus

        init(code: String, label: String, limit: Int, name: String, floorValue: Double, status: SeasonalInteractionAgreementStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.name = name
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalInteractionAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalInteractionAgreementStatus.published || next == SeasonalInteractionAgreementStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalInteractionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal interaction agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal interaction agreement") \(code)"
        }

        func netLoad() -> Double {
            return ((floorValue + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInteractionAgreement {
            return SeasonalInteractionAgreement(
                code: code,
                label: label,
                limit: limit,
                name: name,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal interaction agreement in status created.
    static func newSeasonalInteractionAgreement(_ code: String, label: String) -> SeasonalInteractionAgreement {
        return SeasonalInteractionAgreement(
            code: code,
            label: label,
            limit: 0,
            name: "",
            floorValue: 0.0,
            status: SeasonalInteractionAgreementStatus.created
        )
    }
}
