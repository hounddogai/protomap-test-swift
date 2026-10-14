import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score batch is in its life cycle.
    enum DefaultRiskScoreBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default risk score batch and its current status.
    final class DefaultRiskScoreBatch {
        var code: String
        var name: String
        var startsAt: Int
        var facility: String
        var approved: Bool
        var status: DefaultRiskScoreBatchStatus

        init(code: String, name: String, startsAt: Int, facility: String, approved: Bool, status: DefaultRiskScoreBatchStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.facility = facility
            self.approved = approved
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

        func canMoveTo(_ next: DefaultRiskScoreBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultRiskScoreBatchStatus.done
            case .queued:
                return next == DefaultRiskScoreBatchStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultRiskScoreBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> DefaultRiskScoreBatch {
            return DefaultRiskScoreBatch(
                code: code,
                name: name,
                startsAt: startsAt,
                facility: facility,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default risk score batch in status new.
    static func newDefaultRiskScoreBatch(_ code: String, name: String) -> DefaultRiskScoreBatch {
        return DefaultRiskScoreBatch(
            code: code,
            name: name,
            startsAt: 0,
            facility: "",
            approved: false,
            status: DefaultRiskScoreBatchStatus.new
        )
    }
}
