import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback modality group is in its life cycle.
    enum FallbackModalityGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback modality group as the modality team keeps it.
    final class FallbackModalityGroup {
        var code: String
        var title: String
        var maximum: Double
        var unit: String
        var diagnosisCode: String
        var priority: Int
        var ward: String
        var floorValue: Double
        var description: String
        var retries: Int
        var status: FallbackModalityGroupStatus

        init(code: String, title: String, maximum: Double, unit: String, diagnosisCode: String, priority: Int, ward: String, floorValue: Double, description: String, retries: Int, status: FallbackModalityGroupStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.unit = unit
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.ward = ward
            self.floorValue = floorValue
            self.description = description
            self.retries = retries
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

        func canMoveTo(_ next: FallbackModalityGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackModalityGroupStatus.ready || next == FallbackModalityGroupStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackModalityGroupStatus.draining || next == FallbackModalityGroupStatus.stopped
            case .draining:
                return next == FallbackModalityGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackModalityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback modality group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(retries) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FallbackModalityGroup {
            return FallbackModalityGroup(
                code: code,
                title: title,
                maximum: maximum,
                unit: unit,
                diagnosisCode: diagnosisCode,
                priority: priority,
                ward: ward,
                floorValue: floorValue,
                description: description,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback modality group in status idle.
    static func newFallbackModalityGroup(_ code: String, title: String) -> FallbackModalityGroup {
        return FallbackModalityGroup(
            code: code,
            title: title,
            maximum: 0.0,
            unit: "",
            diagnosisCode: "",
            priority: 0,
            ward: "",
            floorValue: 0.0,
            description: "",
            retries: 0,
            status: FallbackModalityGroupStatus.idle
        )
    }
}
