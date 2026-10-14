import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality baseline is in its life cycle.
    enum ModalityBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a modality baseline and its current status.
    final class ModalityBaseline {
        var code: String
        var label: String
        var facility: String
        var checksum: String
        var ceiling: Double
        var weight: Double
        var allergy: String
        var limit: Int
        var visitMinutes: Int
        var createdAt: Int
        var region: String
        var status: ModalityBaselineStatus

        init(code: String, label: String, facility: String, checksum: String, ceiling: Double, weight: Double, allergy: String, limit: Int, visitMinutes: Int, createdAt: Int, region: String, status: ModalityBaselineStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.checksum = checksum
            self.ceiling = ceiling
            self.weight = weight
            self.allergy = allergy
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == ModalityBaselineStatus.revoked
            case .granted:
                return next == ModalityBaselineStatus.revoked
            case .revoked:
                return next == ModalityBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("modality baseline") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(limit) + weight) * 100).rounded() / 100
        }

        func copyValue() -> ModalityBaseline {
            return ModalityBaseline(
                code: code,
                label: label,
                facility: facility,
                checksum: checksum,
                ceiling: ceiling,
                weight: weight,
                allergy: allergy,
                limit: limit,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality baseline in status requested.
    static func newModalityBaseline(_ code: String, label: String) -> ModalityBaseline {
        return ModalityBaseline(
            code: code,
            label: label,
            facility: "",
            checksum: "",
            ceiling: 0.0,
            weight: 0.0,
            allergy: "",
            limit: 0,
            visitMinutes: 0,
            createdAt: 0,
            region: "",
            status: ModalityBaselineStatus.requested
        )
    }
}
