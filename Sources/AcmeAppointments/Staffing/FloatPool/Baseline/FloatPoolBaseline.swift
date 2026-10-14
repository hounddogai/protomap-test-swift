import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool baseline is in its life cycle.
    enum FloatPoolBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One float pool baseline, with what the planners need to act on it.
    final class FloatPoolBaseline {
        var code: String
        var label: String
        var patientRef: String
        var startsAt: Int
        var segment: String
        var createdAt: Int
        var dosageMg: Double
        var tags: [String]
        var status: FloatPoolBaselineStatus

        init(code: String, label: String, patientRef: String, startsAt: Int, segment: String, createdAt: Int, dosageMg: Double, tags: [String], status: FloatPoolBaselineStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.startsAt = startsAt
            self.segment = segment
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.tags = tags
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

        func canMoveTo(_ next: FloatPoolBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == FloatPoolBaselineStatus.active || next == FloatPoolBaselineStatus.closed
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
                return next == FloatPoolBaselineStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (Double(createdAt) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolBaseline {
            return FloatPoolBaseline(
                code: code,
                label: label,
                patientRef: patientRef,
                startsAt: startsAt,
                segment: segment,
                createdAt: createdAt,
                dosageMg: dosageMg,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a float pool baseline in status draft.
    static func newFloatPoolBaseline(_ code: String, label: String) -> FloatPoolBaseline {
        return FloatPoolBaseline(
            code: code,
            label: label,
            patientRef: "",
            startsAt: 0,
            segment: "",
            createdAt: 0,
            dosageMg: 0.0,
            tags: [],
            status: FloatPoolBaselineStatus.draft
        )
    }
}
