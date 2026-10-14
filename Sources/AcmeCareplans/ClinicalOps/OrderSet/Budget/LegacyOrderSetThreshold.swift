import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set threshold is in its life cycle.
    enum LegacyOrderSetThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy order set threshold as the order set team keeps it.
    final class LegacyOrderSetThreshold {
        var code: String
        var title: String
        var segment: String
        var acuity: Int
        var attributes: [String: String]
        var windowDays: Int
        var maximum: Double
        var ownerID: String
        var specialty: String
        var region: String
        var status: LegacyOrderSetThresholdStatus

        init(code: String, title: String, segment: String, acuity: Int, attributes: [String: String], windowDays: Int, maximum: Double, ownerID: String, specialty: String, region: String, status: LegacyOrderSetThresholdStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.acuity = acuity
            self.attributes = attributes
            self.windowDays = windowDays
            self.maximum = maximum
            self.ownerID = ownerID
            self.specialty = specialty
            self.region = region
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

        func canMoveTo(_ next: LegacyOrderSetThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LegacyOrderSetThresholdStatus.resolved
            case .resolved:
                return next == LegacyOrderSetThresholdStatus.reopened
            case .reopened:
                return next == LegacyOrderSetThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOrderSetThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy order set threshold") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return ((maximum - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOrderSetThreshold {
            return LegacyOrderSetThreshold(
                code: code,
                title: title,
                segment: segment,
                acuity: acuity,
                attributes: attributes,
                windowDays: windowDays,
                maximum: maximum,
                ownerID: ownerID,
                specialty: specialty,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy order set threshold in status open.
    static func newLegacyOrderSetThreshold(_ code: String, title: String) -> LegacyOrderSetThreshold {
        return LegacyOrderSetThreshold(
            code: code,
            title: title,
            segment: "",
            acuity: 0,
            attributes: [:],
            windowDays: 0,
            maximum: 0.0,
            ownerID: "",
            specialty: "",
            region: "",
            status: LegacyOrderSetThresholdStatus.`open`
        )
    }
}
