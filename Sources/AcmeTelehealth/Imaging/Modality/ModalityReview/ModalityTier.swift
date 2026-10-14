import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality tier is in its life cycle.
    enum ModalityTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality tier as the modality team keeps it.
    final class ModalityTier {
        var code: String
        var name: String
        var visitMinutes: Int
        var summary: String
        var batchSize: Int
        var ward: String
        var minimum: Double
        var payer: String
        var version: Int
        var specialty: String
        var procedureCode: String
        var status: ModalityTierStatus

        init(code: String, name: String, visitMinutes: Int, summary: String, batchSize: Int, ward: String, minimum: Double, payer: String, version: Int, specialty: String, procedureCode: String, status: ModalityTierStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.summary = summary
            self.batchSize = batchSize
            self.ward = ward
            self.minimum = minimum
            self.payer = payer
            self.version = version
            self.specialty = specialty
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ModalityTierStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ModalityTierStatus.rejected || next == ModalityTierStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ModalityTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((minimum - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityTier {
            return ModalityTier(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                summary: summary,
                batchSize: batchSize,
                ward: ward,
                minimum: minimum,
                payer: payer,
                version: version,
                specialty: specialty,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality tier in status proposed.
    static func newModalityTier(_ code: String, name: String) -> ModalityTier {
        return ModalityTier(
            code: code,
            name: name,
            visitMinutes: 0,
            summary: "",
            batchSize: 0,
            ward: "",
            minimum: 0.0,
            payer: "",
            version: 0,
            specialty: "",
            procedureCode: "",
            status: ModalityTierStatus.proposed
        )
    }
}
