import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary task tier is in its life cycle.
    enum PrimaryTaskTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary task tier as the task team keeps it.
    final class PrimaryTaskTier {
        var code: String
        var title: String
        var region: String
        var approved: Bool
        var minimum: Double
        var endsAt: Int
        var unit: String
        var dosageMg: Double
        var status: PrimaryTaskTierStatus

        init(code: String, title: String, region: String, approved: Bool, minimum: Double, endsAt: Int, unit: String, dosageMg: Double, status: PrimaryTaskTierStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.approved = approved
            self.minimum = minimum
            self.endsAt = endsAt
            self.unit = unit
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: PrimaryTaskTierStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryTaskTierStatus.done || next == PrimaryTaskTierStatus.failed
            case .queued:
                return next == PrimaryTaskTierStatus.failed
            case .running:
                return next == PrimaryTaskTierStatus.done || next == PrimaryTaskTierStatus.failed
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

        func moveTo(_ next: PrimaryTaskTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary task tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary task tier") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(endsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> PrimaryTaskTier {
            return PrimaryTaskTier(
                code: code,
                title: title,
                region: region,
                approved: approved,
                minimum: minimum,
                endsAt: endsAt,
                unit: unit,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary task tier in status new.
    static func newPrimaryTaskTier(_ code: String, title: String) -> PrimaryTaskTier {
        return PrimaryTaskTier(
            code: code,
            title: title,
            region: "",
            approved: false,
            minimum: 0.0,
            endsAt: 0,
            unit: "",
            dosageMg: 0.0,
            status: PrimaryTaskTierStatus.new
        )
    }
}
