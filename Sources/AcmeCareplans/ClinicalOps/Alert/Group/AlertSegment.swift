import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert segment is in its life cycle.
    enum AlertSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a alert segment and its current status.
    final class AlertSegment {
        var code: String
        var label: String
        var attributes: [String: String]
        var active: Bool
        var externalRef: String
        var archived: Bool
        var visitMinutes: Int
        var windowDays: Int
        var attempts: Int
        var checksum: String
        var unit: String
        var status: AlertSegmentStatus

        init(code: String, label: String, attributes: [String: String], active: Bool, externalRef: String, archived: Bool, visitMinutes: Int, windowDays: Int, attempts: Int, checksum: String, unit: String, status: AlertSegmentStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.active = active
            self.externalRef = externalRef
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.windowDays = windowDays
            self.attempts = attempts
            self.checksum = checksum
            self.unit = unit
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

        func canMoveTo(_ next: AlertSegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AlertSegmentStatus.completed
            case .inProgress:
                return next == AlertSegmentStatus.completed
            case .completed:
                return next == AlertSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func netExposure() -> Double {
            return ((Double(attempts) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AlertSegment {
            return AlertSegment(
                code: code,
                label: label,
                attributes: attributes,
                active: active,
                externalRef: externalRef,
                archived: archived,
                visitMinutes: visitMinutes,
                windowDays: windowDays,
                attempts: attempts,
                checksum: checksum,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a alert segment in status planned.
    static func newAlertSegment(_ code: String, label: String) -> AlertSegment {
        return AlertSegment(
            code: code,
            label: label,
            attributes: [:],
            active: false,
            externalRef: "",
            archived: false,
            visitMinutes: 0,
            windowDays: 0,
            attempts: 0,
            checksum: "",
            unit: "",
            status: AlertSegmentStatus.planned
        )
    }
}
