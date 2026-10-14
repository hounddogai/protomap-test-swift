import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary baseline is in its life cycle.
    enum FormularyBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a formulary baseline and its current status.
    final class FormularyBaseline {
        var code: String
        var title: String
        var payer: String
        var category: String
        var updatedAt: Int
        var windowDays: Int
        var status: FormularyBaselineStatus

        init(code: String, title: String, payer: String, category: String, updatedAt: Int, windowDays: Int, status: FormularyBaselineStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.category = category
            self.updatedAt = updatedAt
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FormularyBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == FormularyBaselineStatus.warming || next == FormularyBaselineStatus.draining
            case .warming:
                return next == FormularyBaselineStatus.ready
            case .ready:
                return next == FormularyBaselineStatus.stopped
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

        func moveTo(_ next: FormularyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(windowDays) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyBaseline {
            return FormularyBaseline(
                code: code,
                title: title,
                payer: payer,
                category: category,
                updatedAt: updatedAt,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a formulary baseline in status idle.
    static func newFormularyBaseline(_ code: String, title: String) -> FormularyBaseline {
        return FormularyBaseline(
            code: code,
            title: title,
            payer: "",
            category: "",
            updatedAt: 0,
            windowDays: 0,
            status: FormularyBaselineStatus.idle
        )
    }
}
