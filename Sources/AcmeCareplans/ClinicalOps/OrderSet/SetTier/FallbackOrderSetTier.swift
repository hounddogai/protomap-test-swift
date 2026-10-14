import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback order set tier is in its life cycle.
    enum FallbackOrderSetTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback order set tier. Its code is unique within a tenant.
    final class FallbackOrderSetTier {
        var code: String
        var label: String
        var bed: String
        var startsAt: Int
        var ratio: Double
        var visitMinutes: Int
        var country: String
        var encounterID: String
        var visible: Bool
        var reviewer: String
        var durationMinutes: Int
        var status: FallbackOrderSetTierStatus

        init(code: String, label: String, bed: String, startsAt: Int, ratio: Double, visitMinutes: Int, country: String, encounterID: String, visible: Bool, reviewer: String, durationMinutes: Int, status: FallbackOrderSetTierStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.startsAt = startsAt
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.country = country
            self.encounterID = encounterID
            self.visible = visible
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: FallbackOrderSetTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackOrderSetTierStatus.inReview || next == FallbackOrderSetTierStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackOrderSetTierStatus.archived
            case .reopened:
                return next == FallbackOrderSetTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackOrderSetTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback order set tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((Double(visitMinutes) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOrderSetTier {
            return FallbackOrderSetTier(
                code: code,
                label: label,
                bed: bed,
                startsAt: startsAt,
                ratio: ratio,
                visitMinutes: visitMinutes,
                country: country,
                encounterID: encounterID,
                visible: visible,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback order set tier in status open.
    static func newFallbackOrderSetTier(_ code: String, label: String) -> FallbackOrderSetTier {
        return FallbackOrderSetTier(
            code: code,
            label: label,
            bed: "",
            startsAt: 0,
            ratio: 0.0,
            visitMinutes: 0,
            country: "",
            encounterID: "",
            visible: false,
            reviewer: "",
            durationMinutes: 0,
            status: FallbackOrderSetTierStatus.`open`
        )
    }
}
