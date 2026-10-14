import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient handoff audit is in its life cycle.
    enum LenientHandoffAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient handoff audit. Its code is unique within a tenant.
    final class LenientHandoffAudit {
        var code: String
        var title: String
        var visible: Bool
        var specialty: String
        var label: String
        var floorValue: Double
        var phone: String
        var windowDays: Int
        var limit: Int
        var status: LenientHandoffAuditStatus

        init(code: String, title: String, visible: Bool, specialty: String, label: String, floorValue: Double, phone: String, windowDays: Int, limit: Int, status: LenientHandoffAuditStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.specialty = specialty
            self.label = label
            self.floorValue = floorValue
            self.phone = phone
            self.windowDays = windowDays
            self.limit = limit
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

        func canMoveTo(_ next: LenientHandoffAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientHandoffAuditStatus.done || next == LenientHandoffAuditStatus.failed
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

        func moveTo(_ next: LenientHandoffAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient handoff audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient handoff audit") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(windowDays) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LenientHandoffAudit {
            return LenientHandoffAudit(
                code: code,
                title: title,
                visible: visible,
                specialty: specialty,
                label: label,
                floorValue: floorValue,
                phone: phone,
                windowDays: windowDays,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient handoff audit in status new.
    static func newLenientHandoffAudit(_ code: String, title: String) -> LenientHandoffAudit {
        return LenientHandoffAudit(
            code: code,
            title: title,
            visible: false,
            specialty: "",
            label: "",
            floorValue: 0.0,
            phone: "",
            windowDays: 0,
            limit: 0,
            status: LenientHandoffAuditStatus.new
        )
    }
}
