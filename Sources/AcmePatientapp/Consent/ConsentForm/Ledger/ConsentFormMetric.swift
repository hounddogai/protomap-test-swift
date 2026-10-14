import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form metric is in its life cycle.
    enum ConsentFormMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A consent form metric. Its code is unique within a tenant.
    final class ConsentFormMetric {
        var code: String
        var name: String
        var priority: Int
        var visible: Bool
        var facility: String
        var createdAt: Int
        var acuity: Int
        var summary: String
        var ratio: Double
        var status: ConsentFormMetricStatus

        init(code: String, name: String, priority: Int, visible: Bool, facility: String, createdAt: Int, acuity: Int, summary: String, ratio: Double, status: ConsentFormMetricStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.visible = visible
            self.facility = facility
            self.createdAt = createdAt
            self.acuity = acuity
            self.summary = summary
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ConsentFormMetricStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ConsentFormMetricStatus.reopened || next == ConsentFormMetricStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ConsentFormMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return (Double(acuity) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormMetric {
            return ConsentFormMetric(
                code: code,
                name: name,
                priority: priority,
                visible: visible,
                facility: facility,
                createdAt: createdAt,
                acuity: acuity,
                summary: summary,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a consent form metric in status open.
    static func newConsentFormMetric(_ code: String, name: String) -> ConsentFormMetric {
        return ConsentFormMetric(
            code: code,
            name: name,
            priority: 0,
            visible: false,
            facility: "",
            createdAt: 0,
            acuity: 0,
            summary: "",
            ratio: 0.0,
            status: ConsentFormMetricStatus.`open`
        )
    }
}
