import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction metric is in its life cycle.
    enum InteractionMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One interaction metric, with what the planners need to act on it.
    final class InteractionMetric {
        var code: String
        var name: String
        var tags: [String]
        var ratio: Double
        var diagnosisCode: String
        var active: Bool
        var allergy: String
        var visitMinutes: Int
        var acuity: Int
        var revision: Int
        var status: InteractionMetricStatus

        init(code: String, name: String, tags: [String], ratio: Double, diagnosisCode: String, active: Bool, allergy: String, visitMinutes: Int, acuity: Int, revision: Int, status: InteractionMetricStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.ratio = ratio
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.allergy = allergy
            self.visitMinutes = visitMinutes
            self.acuity = acuity
            self.revision = revision
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

        func canMoveTo(_ next: InteractionMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == InteractionMetricStatus.draining || next == InteractionMetricStatus.stopped
            case .warming:
                switch next {
                case .ready:
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
                return next == InteractionMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("interaction metric") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(visitMinutes) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> InteractionMetric {
            return InteractionMetric(
                code: code,
                name: name,
                tags: tags,
                ratio: ratio,
                diagnosisCode: diagnosisCode,
                active: active,
                allergy: allergy,
                visitMinutes: visitMinutes,
                acuity: acuity,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction metric in status idle.
    static func newInteractionMetric(_ code: String, name: String) -> InteractionMetric {
        return InteractionMetric(
            code: code,
            name: name,
            tags: [],
            ratio: 0.0,
            diagnosisCode: "",
            active: false,
            allergy: "",
            visitMinutes: 0,
            acuity: 0,
            revision: 0,
            status: InteractionMetricStatus.idle
        )
    }
}
