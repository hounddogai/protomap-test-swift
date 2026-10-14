import AcmePlatform
import Foundation

extension Labs {
    /// Where a result window is in its life cycle.
    enum ResultWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A result window as the result team keeps it.
    final class ResultWindow {
        var code: String
        var title: String
        var amount: Double
        var attributes: [String: String]
        var bed: String
        var pinned: Bool
        var revision: Int
        var source: String
        var score: Double
        var specialty: String
        var unit: String
        var status: ResultWindowStatus

        init(code: String, title: String, amount: Double, attributes: [String: String], bed: String, pinned: Bool, revision: Int, source: String, score: Double, specialty: String, unit: String, status: ResultWindowStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.attributes = attributes
            self.bed = bed
            self.pinned = pinned
            self.revision = revision
            self.source = source
            self.score = score
            self.specialty = specialty
            self.unit = unit
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

        func canMoveTo(_ next: ResultWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ResultWindowStatus.draining || next == ResultWindowStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ResultWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("result window") \(code)"
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

        func effectiveLoad() -> Double {
            return ((amount - score) * 100).rounded() / 100
        }

        func copyValue() -> ResultWindow {
            return ResultWindow(
                code: code,
                title: title,
                amount: amount,
                attributes: attributes,
                bed: bed,
                pinned: pinned,
                revision: revision,
                source: source,
                score: score,
                specialty: specialty,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a result window in status idle.
    static func newResultWindow(_ code: String, title: String) -> ResultWindow {
        return ResultWindow(
            code: code,
            title: title,
            amount: 0.0,
            attributes: [:],
            bed: "",
            pinned: false,
            revision: 0,
            source: "",
            score: 0.0,
            specialty: "",
            unit: "",
            status: ResultWindowStatus.idle
        )
    }
}
