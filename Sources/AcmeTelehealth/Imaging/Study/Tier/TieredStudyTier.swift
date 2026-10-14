import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study tier is in its life cycle.
    enum TieredStudyTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered study tier as the study team keeps it.
    final class TieredStudyTier {
        var code: String
        var label: String
        var procedureCode: String
        var attributes: [String: String]
        var pinned: Bool
        var quantity: Int
        var status: TieredStudyTierStatus

        init(code: String, label: String, procedureCode: String, attributes: [String: String], pinned: Bool, quantity: Int, status: TieredStudyTierStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.pinned = pinned
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredStudyTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredStudyTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStudyTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TieredStudyTier {
            return TieredStudyTier(
                code: code,
                label: label,
                procedureCode: procedureCode,
                attributes: attributes,
                pinned: pinned,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered study tier in status draft.
    static func newTieredStudyTier(_ code: String, label: String) -> TieredStudyTier {
        return TieredStudyTier(
            code: code,
            label: label,
            procedureCode: "",
            attributes: [:],
            pinned: false,
            quantity: 0,
            status: TieredStudyTierStatus.draft
        )
    }
}
