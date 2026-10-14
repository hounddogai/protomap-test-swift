import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel slot is in its life cycle.
    enum PanelSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A panel slot as the panel team keeps it.
    final class PanelSlot {
        var code: String
        var label: String
        var reviewer: String
        var expiresAt: Int
        var unit: String
        var bed: String
        var version: Int
        var ceiling: Double
        var clinicianID: String
        var minimum: Double
        var country: String
        var status: PanelSlotStatus

        init(code: String, label: String, reviewer: String, expiresAt: Int, unit: String, bed: String, version: Int, ceiling: Double, clinicianID: String, minimum: Double, country: String, status: PanelSlotStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.unit = unit
            self.bed = bed
            self.version = version
            self.ceiling = ceiling
            self.clinicianID = clinicianID
            self.minimum = minimum
            self.country = country
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

        func canMoveTo(_ next: PanelSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == PanelSlotStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PanelSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("panel slot") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(expiresAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PanelSlot {
            return PanelSlot(
                code: code,
                label: label,
                reviewer: reviewer,
                expiresAt: expiresAt,
                unit: unit,
                bed: bed,
                version: version,
                ceiling: ceiling,
                clinicianID: clinicianID,
                minimum: minimum,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a panel slot in status new.
    static func newPanelSlot(_ code: String, label: String) -> PanelSlot {
        return PanelSlot(
            code: code,
            label: label,
            reviewer: "",
            expiresAt: 0,
            unit: "",
            bed: "",
            version: 0,
            ceiling: 0.0,
            clinicianID: "",
            minimum: 0.0,
            country: "",
            status: PanelSlotStatus.new
        )
    }
}
