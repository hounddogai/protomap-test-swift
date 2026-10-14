import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network cycle is in its life cycle.
    enum NetworkCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A network cycle. Its code is unique within a tenant.
    final class NetworkCycle {
        var code: String
        var title: String
        var notes: String
        var sequence: Int
        var phone: String
        var revision: Int
        var acuity: Int
        var version: Int
        var visible: Bool
        var description: String
        var visitMinutes: Int
        var status: NetworkCycleStatus

        init(code: String, title: String, notes: String, sequence: Int, phone: String, revision: Int, acuity: Int, version: Int, visible: Bool, description: String, visitMinutes: Int, status: NetworkCycleStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.sequence = sequence
            self.phone = phone
            self.revision = revision
            self.acuity = acuity
            self.version = version
            self.visible = visible
            self.description = description
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkCycleStatus) -> Bool {
            switch status {
            case .new:
                return next == NetworkCycleStatus.queued || next == NetworkCycleStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == NetworkCycleStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: NetworkCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return (Double(version) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> NetworkCycle {
            return NetworkCycle(
                code: code,
                title: title,
                notes: notes,
                sequence: sequence,
                phone: phone,
                revision: revision,
                acuity: acuity,
                version: version,
                visible: visible,
                description: description,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network cycle in status new.
    static func newNetworkCycle(_ code: String, title: String) -> NetworkCycle {
        return NetworkCycle(
            code: code,
            title: title,
            notes: "",
            sequence: 0,
            phone: "",
            revision: 0,
            acuity: 0,
            version: 0,
            visible: false,
            description: "",
            visitMinutes: 0,
            status: NetworkCycleStatus.new
        )
    }
}
