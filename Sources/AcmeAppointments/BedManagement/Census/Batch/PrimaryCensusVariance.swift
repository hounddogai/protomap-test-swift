import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary census variance is in its life cycle.
    enum PrimaryCensusVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary census variance as the census team keeps it.
    final class PrimaryCensusVariance {
        var code: String
        var label: String
        var version: Int
        var contactEmail: String
        var tags: [String]
        var country: String
        var status: PrimaryCensusVarianceStatus

        init(code: String, label: String, version: Int, contactEmail: String, tags: [String], country: String, status: PrimaryCensusVarianceStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.contactEmail = contactEmail
            self.tags = tags
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCensusVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryCensusVarianceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCensusVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary census variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> PrimaryCensusVariance {
            return PrimaryCensusVariance(
                code: code,
                label: label,
                version: version,
                contactEmail: contactEmail,
                tags: tags,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary census variance in status created.
    static func newPrimaryCensusVariance(_ code: String, label: String) -> PrimaryCensusVariance {
        return PrimaryCensusVariance(
            code: code,
            label: label,
            version: 0,
            contactEmail: "",
            tags: [],
            country: "",
            status: PrimaryCensusVarianceStatus.created
        )
    }
}
