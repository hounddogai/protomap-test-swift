import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read policy is in its life cycle.
    enum ReadPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A read policy as the read team keeps it.
    final class ReadPolicy {
        var code: String
        var label: String
        var durationMinutes: Int
        var allergy: String
        var notes: String
        var createdAt: Int
        var specialty: String
        var priority: Int
        var status: ReadPolicyStatus

        init(code: String, label: String, durationMinutes: Int, allergy: String, notes: String, createdAt: Int, specialty: String, priority: Int, status: ReadPolicyStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.notes = notes
            self.createdAt = createdAt
            self.specialty = specialty
            self.priority = priority
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

        func canMoveTo(_ next: ReadPolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReadPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("read policy") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(priority) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ReadPolicy {
            return ReadPolicy(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                allergy: allergy,
                notes: notes,
                createdAt: createdAt,
                specialty: specialty,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read policy in status created.
    static func newReadPolicy(_ code: String, label: String) -> ReadPolicy {
        return ReadPolicy(
            code: code,
            label: label,
            durationMinutes: 0,
            allergy: "",
            notes: "",
            createdAt: 0,
            specialty: "",
            priority: 0,
            status: ReadPolicyStatus.created
        )
    }
}
