import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel profile is in its life cycle.
    enum PanelProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A panel profile. Its code is unique within a tenant.
    final class PanelProfile {
        var code: String
        var name: String
        var reviewer: String
        var summary: String
        var currency: String
        var phone: String
        var country: String
        var retries: Int
        var dosageMg: Double
        var status: PanelProfileStatus

        init(code: String, name: String, reviewer: String, summary: String, currency: String, phone: String, country: String, retries: Int, dosageMg: Double, status: PanelProfileStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.summary = summary
            self.currency = currency
            self.phone = phone
            self.country = country
            self.retries = retries
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: PanelProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PanelProfileStatus.done || next == PanelProfileStatus.failed
            case .done:
                return next == PanelProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (dosageMg * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PanelProfile {
            return PanelProfile(
                code: code,
                name: name,
                reviewer: reviewer,
                summary: summary,
                currency: currency,
                phone: phone,
                country: country,
                retries: retries,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a panel profile in status new.
    static func newPanelProfile(_ code: String, name: String) -> PanelProfile {
        return PanelProfile(
            code: code,
            name: name,
            reviewer: "",
            summary: "",
            currency: "",
            phone: "",
            country: "",
            retries: 0,
            dosageMg: 0.0,
            status: PanelProfileStatus.new
        )
    }
}
