import AcmePlatform
import Foundation

extension Labs {
    /// Where a result metric is in its life cycle.
    enum ResultMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a result metric and its current status.
    final class ResultMetric {
        var code: String
        var name: String
        var attempts: Int
        var phone: String
        var limit: Int
        var margin: Double
        var checksum: String
        var notes: String
        var diagnosisCode: String
        var approved: Bool
        var title: String
        var status: ResultMetricStatus

        init(code: String, name: String, attempts: Int, phone: String, limit: Int, margin: Double, checksum: String, notes: String, diagnosisCode: String, approved: Bool, title: String, status: ResultMetricStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.phone = phone
            self.limit = limit
            self.margin = margin
            self.checksum = checksum
            self.notes = notes
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ResultMetricStatus.withdrawn
            case .approved:
                return next == ResultMetricStatus.rejected || next == ResultMetricStatus.withdrawn
            case .rejected:
                return next == ResultMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveValue() -> Double {
            return (Double(attempts) * margin * 100).rounded() / 100
        }

        func copyValue() -> ResultMetric {
            return ResultMetric(
                code: code,
                name: name,
                attempts: attempts,
                phone: phone,
                limit: limit,
                margin: margin,
                checksum: checksum,
                notes: notes,
                diagnosisCode: diagnosisCode,
                approved: approved,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a result metric in status proposed.
    static func newResultMetric(_ code: String, name: String) -> ResultMetric {
        return ResultMetric(
            code: code,
            name: name,
            attempts: 0,
            phone: "",
            limit: 0,
            margin: 0.0,
            checksum: "",
            notes: "",
            diagnosisCode: "",
            approved: false,
            title: "",
            status: ResultMetricStatus.proposed
        )
    }
}
