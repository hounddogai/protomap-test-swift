import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality preference is in its life cycle.
    enum CappedModalityPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped modality preference. Its code is unique within a tenant.
    final class CappedModalityPreference {
        var code: String
        var title: String
        var quantity: Int
        var budget: Double
        var retries: Int
        var unit: String
        var visitMinutes: Int
        var archived: Bool
        var status: CappedModalityPreferenceStatus

        init(code: String, title: String, quantity: Int, budget: Double, retries: Int, unit: String, visitMinutes: Int, archived: Bool, status: CappedModalityPreferenceStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.budget = budget
            self.retries = retries
            self.unit = unit
            self.visitMinutes = visitMinutes
            self.archived = archived
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

        func canMoveTo(_ next: CappedModalityPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedModalityPreferenceStatus.ready || next == CappedModalityPreferenceStatus.draining
            case .ready:
                return next == CappedModalityPreferenceStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedModalityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(visitMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityPreference {
            return CappedModalityPreference(
                code: code,
                title: title,
                quantity: quantity,
                budget: budget,
                retries: retries,
                unit: unit,
                visitMinutes: visitMinutes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped modality preference in status idle.
    static func newCappedModalityPreference(_ code: String, title: String) -> CappedModalityPreference {
        return CappedModalityPreference(
            code: code,
            title: title,
            quantity: 0,
            budget: 0.0,
            retries: 0,
            unit: "",
            visitMinutes: 0,
            archived: false,
            status: CappedModalityPreferenceStatus.idle
        )
    }
}
