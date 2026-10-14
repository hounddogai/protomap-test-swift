import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality mapping is in its life cycle.
    enum CappedModalityMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped modality mapping. Its code is unique within a tenant.
    final class CappedModalityMapping {
        var code: String
        var title: String
        var minimum: Double
        var margin: Double
        var startsAt: Int
        var externalRef: String
        var status: CappedModalityMappingStatus

        init(code: String, title: String, minimum: Double, margin: Double, startsAt: Int, externalRef: String, status: CappedModalityMappingStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.margin = margin
            self.startsAt = startsAt
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CappedModalityMappingStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CappedModalityMappingStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedModalityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((margin - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityMapping {
            return CappedModalityMapping(
                code: code,
                title: title,
                minimum: minimum,
                margin: margin,
                startsAt: startsAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped modality mapping in status requested.
    static func newCappedModalityMapping(_ code: String, title: String) -> CappedModalityMapping {
        return CappedModalityMapping(
            code: code,
            title: title,
            minimum: 0.0,
            margin: 0.0,
            startsAt: 0,
            externalRef: "",
            status: CappedModalityMappingStatus.requested
        )
    }
}
