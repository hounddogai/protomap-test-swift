import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study baseline is in its life cycle.
    enum StudyBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a study baseline and its current status.
    final class StudyBaseline {
        var code: String
        var label: String
        var windowDays: Int
        var notes: String
        var quantity: Int
        var rate: Double
        var ward: String
        var source: String
        var dosageMg: Double
        var status: StudyBaselineStatus

        init(code: String, label: String, windowDays: Int, notes: String, quantity: Int, rate: Double, ward: String, source: String, dosageMg: Double, status: StudyBaselineStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.notes = notes
            self.quantity = quantity
            self.rate = rate
            self.ward = ward
            self.source = source
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StudyBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StudyBaselineStatus.reopened || next == StudyBaselineStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: StudyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((dosageMg - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> StudyBaseline {
            return StudyBaseline(
                code: code,
                label: label,
                windowDays: windowDays,
                notes: notes,
                quantity: quantity,
                rate: rate,
                ward: ward,
                source: source,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a study baseline in status open.
    static func newStudyBaseline(_ code: String, label: String) -> StudyBaseline {
        return StudyBaseline(
            code: code,
            label: label,
            windowDays: 0,
            notes: "",
            quantity: 0,
            rate: 0.0,
            ward: "",
            source: "",
            dosageMg: 0.0,
            status: StudyBaselineStatus.`open`
        )
    }
}
