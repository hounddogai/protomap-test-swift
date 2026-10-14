import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global outreach agreement is in its life cycle.
    enum GlobalOutreachAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global outreach agreement as the outreach team keeps it.
    final class GlobalOutreachAgreement {
        var code: String
        var title: String
        var approved: Bool
        var timezone: String
        var ratio: Double
        var dosageMg: Double
        var createdAt: Int
        var source: String
        var status: GlobalOutreachAgreementStatus

        init(code: String, title: String, approved: Bool, timezone: String, ratio: Double, dosageMg: Double, createdAt: Int, source: String, status: GlobalOutreachAgreementStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.timezone = timezone
            self.ratio = ratio
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.source = source
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

        func canMoveTo(_ next: GlobalOutreachAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalOutreachAgreementStatus.ready || next == GlobalOutreachAgreementStatus.stopped
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
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalOutreachAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOutreachAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global outreach agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((ratio + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOutreachAgreement {
            return GlobalOutreachAgreement(
                code: code,
                title: title,
                approved: approved,
                timezone: timezone,
                ratio: ratio,
                dosageMg: dosageMg,
                createdAt: createdAt,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global outreach agreement in status idle.
    static func newGlobalOutreachAgreement(_ code: String, title: String) -> GlobalOutreachAgreement {
        return GlobalOutreachAgreement(
            code: code,
            title: title,
            approved: false,
            timezone: "",
            ratio: 0.0,
            dosageMg: 0.0,
            createdAt: 0,
            source: "",
            status: GlobalOutreachAgreementStatus.idle
        )
    }
}
