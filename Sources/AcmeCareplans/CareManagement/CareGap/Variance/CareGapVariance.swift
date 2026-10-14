import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap variance is in its life cycle.
    enum CareGapVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One care gap variance, with what the planners need to act on it.
    final class CareGapVariance {
        var code: String
        var title: String
        var capacity: Int
        var source: String
        var specialty: String
        var budget: Double
        var threshold: Double
        var category: String
        var dosageMg: Double
        var checksum: String
        var ceiling: Double
        var status: CareGapVarianceStatus

        init(code: String, title: String, capacity: Int, source: String, specialty: String, budget: Double, threshold: Double, category: String, dosageMg: Double, checksum: String, ceiling: Double, status: CareGapVarianceStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.source = source
            self.specialty = specialty
            self.budget = budget
            self.threshold = threshold
            self.category = category
            self.dosageMg = dosageMg
            self.checksum = checksum
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CareGapVarianceStatus.rejected
            case .rejected:
                return next == CareGapVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((dosageMg - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CareGapVariance {
            return CareGapVariance(
                code: code,
                title: title,
                capacity: capacity,
                source: source,
                specialty: specialty,
                budget: budget,
                threshold: threshold,
                category: category,
                dosageMg: dosageMg,
                checksum: checksum,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care gap variance in status proposed.
    static func newCareGapVariance(_ code: String, title: String) -> CareGapVariance {
        return CareGapVariance(
            code: code,
            title: title,
            capacity: 0,
            source: "",
            specialty: "",
            budget: 0.0,
            threshold: 0.0,
            category: "",
            dosageMg: 0.0,
            checksum: "",
            ceiling: 0.0,
            status: CareGapVarianceStatus.proposed
        )
    }
}
