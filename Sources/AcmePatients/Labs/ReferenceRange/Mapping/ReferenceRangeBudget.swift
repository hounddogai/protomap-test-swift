import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range budget is in its life cycle.
    enum ReferenceRangeBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a reference range budget and its current status.
    final class ReferenceRangeBudget {
        var code: String
        var label: String
        var batchSize: Int
        var ratio: Double
        var ward: String
        var category: String
        var limit: Int
        var archived: Bool
        var status: ReferenceRangeBudgetStatus

        init(code: String, label: String, batchSize: Int, ratio: Double, ward: String, category: String, limit: Int, archived: Bool, status: ReferenceRangeBudgetStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.ratio = ratio
            self.ward = ward
            self.category = category
            self.limit = limit
            self.archived = archived
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

        func canMoveTo(_ next: ReferenceRangeBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReferenceRangeBudgetStatus.granted || next == ReferenceRangeBudgetStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: ReferenceRangeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((ratio - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeBudget {
            return ReferenceRangeBudget(
                code: code,
                label: label,
                batchSize: batchSize,
                ratio: ratio,
                ward: ward,
                category: category,
                limit: limit,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a reference range budget in status requested.
    static func newReferenceRangeBudget(_ code: String, label: String) -> ReferenceRangeBudget {
        return ReferenceRangeBudget(
            code: code,
            label: label,
            batchSize: 0,
            ratio: 0.0,
            ward: "",
            category: "",
            limit: 0,
            archived: false,
            status: ReferenceRangeBudgetStatus.requested
        )
    }
}
