import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary interaction template is in its life cycle.
    enum PrimaryInteractionTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary interaction template as the interaction team keeps it.
    final class PrimaryInteractionTemplate {
        var code: String
        var label: String
        var rate: Double
        var country: String
        var ratio: Double
        var timezone: String
        var version: Int
        var ward: String
        var minimum: Double
        var notes: String
        var status: PrimaryInteractionTemplateStatus

        init(code: String, label: String, rate: Double, country: String, ratio: Double, timezone: String, version: Int, ward: String, minimum: Double, notes: String, status: PrimaryInteractionTemplateStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.country = country
            self.ratio = ratio
            self.timezone = timezone
            self.version = version
            self.ward = ward
            self.minimum = minimum
            self.notes = notes
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

        func canMoveTo(_ next: PrimaryInteractionTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
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
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryInteractionTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryInteractionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary interaction template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("primary interaction template") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(version) - rate) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInteractionTemplate {
            return PrimaryInteractionTemplate(
                code: code,
                label: label,
                rate: rate,
                country: country,
                ratio: ratio,
                timezone: timezone,
                version: version,
                ward: ward,
                minimum: minimum,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary interaction template in status new.
    static func newPrimaryInteractionTemplate(_ code: String, label: String) -> PrimaryInteractionTemplate {
        return PrimaryInteractionTemplate(
            code: code,
            label: label,
            rate: 0.0,
            country: "",
            ratio: 0.0,
            timezone: "",
            version: 0,
            ward: "",
            minimum: 0.0,
            notes: "",
            status: PrimaryInteractionTemplateStatus.new
        )
    }
}
