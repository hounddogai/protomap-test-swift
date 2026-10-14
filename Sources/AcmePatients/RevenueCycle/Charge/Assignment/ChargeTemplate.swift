import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge template is in its life cycle.
    enum ChargeTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge template. Its code is unique within a tenant.
    final class ChargeTemplate {
        var code: String
        var label: String
        var acuity: Int
        var createdAt: Int
        var graceDays: Int
        var weight: Double
        var segment: String
        var visitMinutes: Int
        var status: ChargeTemplateStatus

        init(code: String, label: String, acuity: Int, createdAt: Int, graceDays: Int, weight: Double, segment: String, visitMinutes: Int, status: ChargeTemplateStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.weight = weight
            self.segment = segment
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ChargeTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ChargeTemplateStatus.reopened || next == ChargeTemplateStatus.archived
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

        func moveTo(_ next: ChargeTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ChargeTemplate {
            return ChargeTemplate(
                code: code,
                label: label,
                acuity: acuity,
                createdAt: createdAt,
                graceDays: graceDays,
                weight: weight,
                segment: segment,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a charge template in status open.
    static func newChargeTemplate(_ code: String, label: String) -> ChargeTemplate {
        return ChargeTemplate(
            code: code,
            label: label,
            acuity: 0,
            createdAt: 0,
            graceDays: 0,
            weight: 0.0,
            segment: "",
            visitMinutes: 0,
            status: ChargeTemplateStatus.`open`
        )
    }
}
