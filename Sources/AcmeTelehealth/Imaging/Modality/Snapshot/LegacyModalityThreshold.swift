import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality threshold is in its life cycle.
    enum LegacyModalityThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy modality threshold and its current status.
    final class LegacyModalityThreshold {
        var code: String
        var name: String
        var ceiling: Double
        var source: String
        var dosageMg: Double
        var archived: Bool
        var status: LegacyModalityThresholdStatus

        init(code: String, name: String, ceiling: Double, source: String, dosageMg: Double, archived: Bool, status: LegacyModalityThresholdStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.source = source
            self.dosageMg = dosageMg
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyModalityThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyModalityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return (dosageMg * ceiling * 100).rounded() / 100
        }

        func copyValue() -> LegacyModalityThreshold {
            return LegacyModalityThreshold(
                code: code,
                name: name,
                ceiling: ceiling,
                source: source,
                dosageMg: dosageMg,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy modality threshold in status proposed.
    static func newLegacyModalityThreshold(_ code: String, name: String) -> LegacyModalityThreshold {
        return LegacyModalityThreshold(
            code: code,
            name: name,
            ceiling: 0.0,
            source: "",
            dosageMg: 0.0,
            archived: false,
            status: LegacyModalityThresholdStatus.proposed
        )
    }
}
