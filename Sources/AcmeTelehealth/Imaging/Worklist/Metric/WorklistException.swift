import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist exception is in its life cycle.
    enum WorklistExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A worklist exception as the worklist team keeps it.
    final class WorklistException {
        var code: String
        var title: String
        var attempts: Int
        var limit: Int
        var visible: Bool
        var diagnosisCode: String
        var attributes: [String: String]
        var rate: Double
        var ward: String
        var startsAt: Int
        var status: WorklistExceptionStatus

        init(code: String, title: String, attempts: Int, limit: Int, visible: Bool, diagnosisCode: String, attributes: [String: String], rate: Double, ward: String, startsAt: Int, status: WorklistExceptionStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.limit = limit
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.rate = rate
            self.ward = ward
            self.startsAt = startsAt
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

        func canMoveTo(_ next: WorklistExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == WorklistExceptionStatus.ready || next == WorklistExceptionStatus.draining
            case .warming:
                return next == WorklistExceptionStatus.draining
            case .ready:
                return next == WorklistExceptionStatus.draining || next == WorklistExceptionStatus.stopped
            case .draining:
                return next == WorklistExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func adjustedVolume() -> Double {
            return (Double(limit) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> WorklistException {
            return WorklistException(
                code: code,
                title: title,
                attempts: attempts,
                limit: limit,
                visible: visible,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                rate: rate,
                ward: ward,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a worklist exception in status idle.
    static func newWorklistException(_ code: String, title: String) -> WorklistException {
        return WorklistException(
            code: code,
            title: title,
            attempts: 0,
            limit: 0,
            visible: false,
            diagnosisCode: "",
            attributes: [:],
            rate: 0.0,
            ward: "",
            startsAt: 0,
            status: WorklistExceptionStatus.idle
        )
    }
}
