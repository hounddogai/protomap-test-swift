import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan batch is in its life cycle.
    enum AcuityPlanBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One acuity plan batch, with what the planners need to act on it.
    final class AcuityPlanBatch {
        var code: String
        var name: String
        var allergy: String
        var dosageMg: Double
        var title: String
        var label: String
        var externalRef: String
        var timezone: String
        var source: String
        var expiresAt: Int
        var status: AcuityPlanBatchStatus

        init(code: String, name: String, allergy: String, dosageMg: Double, title: String, label: String, externalRef: String, timezone: String, source: String, expiresAt: Int, status: AcuityPlanBatchStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.title = title
            self.label = label
            self.externalRef = externalRef
            self.timezone = timezone
            self.source = source
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AcuityPlanBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AcuityPlanBatchStatus.running || next == AcuityPlanBatchStatus.failed
            case .running:
                return next == AcuityPlanBatchStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AcuityPlanBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanBatch {
            return AcuityPlanBatch(
                code: code,
                name: name,
                allergy: allergy,
                dosageMg: dosageMg,
                title: title,
                label: label,
                externalRef: externalRef,
                timezone: timezone,
                source: source,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a acuity plan batch in status new.
    static func newAcuityPlanBatch(_ code: String, name: String) -> AcuityPlanBatch {
        return AcuityPlanBatch(
            code: code,
            name: name,
            allergy: "",
            dosageMg: 0.0,
            title: "",
            label: "",
            externalRef: "",
            timezone: "",
            source: "",
            expiresAt: 0,
            status: AcuityPlanBatchStatus.new
        )
    }
}
