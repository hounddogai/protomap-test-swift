import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled closure request is in its life cycle.
    enum ScheduledClosureRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled closure request, with what the planners need to act on it.
    final class ScheduledClosureRequest {
        var code: String
        var title: String
        var country: String
        var updatedAt: Int
        var batchSize: Int
        var diagnosisCode: String
        var sequence: Int
        var status: ScheduledClosureRequestStatus

        init(code: String, title: String, country: String, updatedAt: Int, batchSize: Int, diagnosisCode: String, sequence: Int, status: ScheduledClosureRequestStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.updatedAt = updatedAt
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
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

        func canMoveTo(_ next: ScheduledClosureRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledClosureRequestStatus.done
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

        func moveTo(_ next: ScheduledClosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled closure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(sequence) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledClosureRequest {
            return ScheduledClosureRequest(
                code: code,
                title: title,
                country: country,
                updatedAt: updatedAt,
                batchSize: batchSize,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled closure request in status new.
    static func newScheduledClosureRequest(_ code: String, title: String) -> ScheduledClosureRequest {
        return ScheduledClosureRequest(
            code: code,
            title: title,
            country: "",
            updatedAt: 0,
            batchSize: 0,
            diagnosisCode: "",
            sequence: 0,
            status: ScheduledClosureRequestStatus.new
        )
    }
}
