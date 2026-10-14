import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form segment is in its life cycle.
    enum ConsentFormSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One consent form segment, with what the planners need to act on it.
    final class ConsentFormSegment {
        var code: String
        var label: String
        var createdAt: Int
        var region: String
        var dosageMg: Double
        var locale: String
        var status: ConsentFormSegmentStatus

        init(code: String, label: String, createdAt: Int, region: String, dosageMg: Double, locale: String, status: ConsentFormSegmentStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.region = region
            self.dosageMg = dosageMg
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ConsentFormSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("consent form segment") \(code)"
        }

        func netValue() -> Double {
            return (dosageMg * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormSegment {
            return ConsentFormSegment(
                code: code,
                label: label,
                createdAt: createdAt,
                region: region,
                dosageMg: dosageMg,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a consent form segment in status draft.
    static func newConsentFormSegment(_ code: String, label: String) -> ConsentFormSegment {
        return ConsentFormSegment(
            code: code,
            label: label,
            createdAt: 0,
            region: "",
            dosageMg: 0.0,
            locale: "",
            status: ConsentFormSegmentStatus.draft
        )
    }
}
