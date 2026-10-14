import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel metric is in its life cycle.
    enum PanelMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a panel metric and its current status.
    final class PanelMetric {
        var code: String
        var title: String
        var refills: Int
        var facility: String
        var pinned: Bool
        var visitMinutes: Int
        var budget: Double
        var capacity: Int
        var source: String
        var expiresAt: Int
        var status: PanelMetricStatus

        init(code: String, title: String, refills: Int, facility: String, pinned: Bool, visitMinutes: Int, budget: Double, capacity: Int, source: String, expiresAt: Int, status: PanelMetricStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.facility = facility
            self.pinned = pinned
            self.visitMinutes = visitMinutes
            self.budget = budget
            self.capacity = capacity
            self.source = source
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: PanelMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelMetricStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: PanelMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("panel metric") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(expiresAt) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PanelMetric {
            return PanelMetric(
                code: code,
                title: title,
                refills: refills,
                facility: facility,
                pinned: pinned,
                visitMinutes: visitMinutes,
                budget: budget,
                capacity: capacity,
                source: source,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a panel metric in status planned.
    static func newPanelMetric(_ code: String, title: String) -> PanelMetric {
        return PanelMetric(
            code: code,
            title: title,
            refills: 0,
            facility: "",
            pinned: false,
            visitMinutes: 0,
            budget: 0.0,
            capacity: 0,
            source: "",
            expiresAt: 0,
            status: PanelMetricStatus.planned
        )
    }
}
