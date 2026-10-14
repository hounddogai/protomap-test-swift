import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense record is in its life cycle.
    enum DispenseRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A dispense record. Its code is unique within a tenant.
    final class DispenseRecord {
        var code: String
        var name: String
        var ownerID: String
        var score: Double
        var copay: Double
        var status: DispenseRecordStatus

        init(code: String, name: String, ownerID: String, score: Double, copay: Double, status: DispenseRecordStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.score = score
            self.copay = copay
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

        func canMoveTo(_ next: DispenseRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DispenseRecordStatus.ready || next == DispenseRecordStatus.stopped
            case .ready:
                return next == DispenseRecordStatus.draining || next == DispenseRecordStatus.stopped
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

        func moveTo(_ next: DispenseRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (copay * score * 100).rounded() / 100
        }

        func copyValue() -> DispenseRecord {
            return DispenseRecord(
                code: code,
                name: name,
                ownerID: ownerID,
                score: score,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense record in status idle.
    static func newDispenseRecord(_ code: String, name: String) -> DispenseRecord {
        return DispenseRecord(
            code: code,
            name: name,
            ownerID: "",
            score: 0.0,
            copay: 0.0,
            status: DispenseRecordStatus.idle
        )
    }
}
