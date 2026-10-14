import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap bundle is in its life cycle.
    enum CareGapBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care gap bundle and its current status.
    final class CareGapBundle {
        var code: String
        var label: String
        var ward: String
        var quantity: Int
        var budget: Double
        var status: CareGapBundleStatus

        init(code: String, label: String, ward: String, quantity: Int, budget: Double, status: CareGapBundleStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.quantity = quantity
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CareGapBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return (budget * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CareGapBundle {
            return CareGapBundle(
                code: code,
                label: label,
                ward: ward,
                quantity: quantity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care gap bundle in status open.
    static func newCareGapBundle(_ code: String, label: String) -> CareGapBundle {
        return CareGapBundle(
            code: code,
            label: label,
            ward: "",
            quantity: 0,
            budget: 0.0,
            status: CareGapBundleStatus.`open`
        )
    }
}
