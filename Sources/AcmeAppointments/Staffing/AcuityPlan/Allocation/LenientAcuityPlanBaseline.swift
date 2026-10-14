import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan baseline is in its life cycle.
    enum LenientAcuityPlanBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient acuity plan baseline, with what the planners need to act on it.
    final class LenientAcuityPlanBaseline {
        var code: String
        var label: String
        var createdAt: Int
        var startsAt: Int
        var payer: String
        var ward: String
        var summary: String
        var status: LenientAcuityPlanBaselineStatus

        init(code: String, label: String, createdAt: Int, startsAt: Int, payer: String, ward: String, summary: String, status: LenientAcuityPlanBaselineStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.payer = payer
            self.ward = ward
            self.summary = summary
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

        func canMoveTo(_ next: LenientAcuityPlanBaselineStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LenientAcuityPlanBaselineStatus.ready || next == LenientAcuityPlanBaselineStatus.stopped
            case .ready:
                return next == LenientAcuityPlanBaselineStatus.draining || next == LenientAcuityPlanBaselineStatus.stopped
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

        func moveTo(_ next: LenientAcuityPlanBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanBaseline {
            return LenientAcuityPlanBaseline(
                code: code,
                label: label,
                createdAt: createdAt,
                startsAt: startsAt,
                payer: payer,
                ward: ward,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient acuity plan baseline in status idle.
    static func newLenientAcuityPlanBaseline(_ code: String, label: String) -> LenientAcuityPlanBaseline {
        return LenientAcuityPlanBaseline(
            code: code,
            label: label,
            createdAt: 0,
            startsAt: 0,
            payer: "",
            ward: "",
            summary: "",
            status: LenientAcuityPlanBaselineStatus.idle
        )
    }
}
