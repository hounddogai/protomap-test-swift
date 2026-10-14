import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense profile is in its life cycle.
    enum DispenseProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A dispense profile as the dispense team keeps it.
    final class DispenseProfile {
        var code: String
        var name: String
        var summary: String
        var dosageMg: Double
        var priority: Int
        var score: Double
        var externalRef: String
        var threshold: Double
        var amount: Double
        var ward: String
        var createdAt: Int
        var status: DispenseProfileStatus

        init(code: String, name: String, summary: String, dosageMg: Double, priority: Int, score: Double, externalRef: String, threshold: Double, amount: Double, ward: String, createdAt: Int, status: DispenseProfileStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.dosageMg = dosageMg
            self.priority = priority
            self.score = score
            self.externalRef = externalRef
            self.threshold = threshold
            self.amount = amount
            self.ward = ward
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == DispenseProfileStatus.completed
            case .scheduled:
                return next == DispenseProfileStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DispenseProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((score + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DispenseProfile {
            return DispenseProfile(
                code: code,
                name: name,
                summary: summary,
                dosageMg: dosageMg,
                priority: priority,
                score: score,
                externalRef: externalRef,
                threshold: threshold,
                amount: amount,
                ward: ward,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a dispense profile in status planned.
    static func newDispenseProfile(_ code: String, name: String) -> DispenseProfile {
        return DispenseProfile(
            code: code,
            name: name,
            summary: "",
            dosageMg: 0.0,
            priority: 0,
            score: 0.0,
            externalRef: "",
            threshold: 0.0,
            amount: 0.0,
            ward: "",
            createdAt: 0,
            status: DispenseProfileStatus.planned
        )
    }
}
