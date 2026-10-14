import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive isolation template is in its life cycle.
    enum AdaptiveIsolationTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a adaptive isolation template and its current status.
    final class AdaptiveIsolationTemplate {
        var code: String
        var title: String
        var visitMinutes: Int
        var procedureCode: String
        var refills: Int
        var active: Bool
        var minimum: Double
        var reviewer: String
        var checksum: String
        var maximum: Double
        var createdAt: Int
        var status: AdaptiveIsolationTemplateStatus

        init(code: String, title: String, visitMinutes: Int, procedureCode: String, refills: Int, active: Bool, minimum: Double, reviewer: String, checksum: String, maximum: Double, createdAt: Int, status: AdaptiveIsolationTemplateStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.refills = refills
            self.active = active
            self.minimum = minimum
            self.reviewer = reviewer
            self.checksum = checksum
            self.maximum = maximum
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AdaptiveIsolationTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptiveIsolationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive isolation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive isolation template") \(code)"
        }

        func netVolume() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveIsolationTemplate {
            return AdaptiveIsolationTemplate(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                refills: refills,
                active: active,
                minimum: minimum,
                reviewer: reviewer,
                checksum: checksum,
                maximum: maximum,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive isolation template in status idle.
    static func newAdaptiveIsolationTemplate(_ code: String, title: String) -> AdaptiveIsolationTemplate {
        return AdaptiveIsolationTemplate(
            code: code,
            title: title,
            visitMinutes: 0,
            procedureCode: "",
            refills: 0,
            active: false,
            minimum: 0.0,
            reviewer: "",
            checksum: "",
            maximum: 0.0,
            createdAt: 0,
            status: AdaptiveIsolationTemplateStatus.idle
        )
    }
}
