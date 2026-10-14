import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range variance is in its life cycle.
    enum LenientReferenceRangeVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One lenient reference range variance, with what the planners need to act on it.
    final class LenientReferenceRangeVariance {
        var code: String
        var title: String
        var expiresAt: Int
        var acuity: Int
        var refills: Int
        var name: String
        var label: String
        var updatedAt: Int
        var floorValue: Double
        var status: LenientReferenceRangeVarianceStatus

        init(code: String, title: String, expiresAt: Int, acuity: Int, refills: Int, name: String, label: String, updatedAt: Int, floorValue: Double, status: LenientReferenceRangeVarianceStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.refills = refills
            self.name = name
            self.label = label
            self.updatedAt = updatedAt
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LenientReferenceRangeVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientReferenceRangeVarianceStatus.published
            case .published:
                return next == LenientReferenceRangeVarianceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReferenceRangeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((floorValue + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeVariance {
            return LenientReferenceRangeVariance(
                code: code,
                title: title,
                expiresAt: expiresAt,
                acuity: acuity,
                refills: refills,
                name: name,
                label: label,
                updatedAt: updatedAt,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient reference range variance in status created.
    static func newLenientReferenceRangeVariance(_ code: String, title: String) -> LenientReferenceRangeVariance {
        return LenientReferenceRangeVariance(
            code: code,
            title: title,
            expiresAt: 0,
            acuity: 0,
            refills: 0,
            name: "",
            label: "",
            updatedAt: 0,
            floorValue: 0.0,
            status: LenientReferenceRangeVarianceStatus.created
        )
    }
}
