import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study batch is in its life cycle.
    enum StudyBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A study batch. Its code is unique within a tenant.
    final class StudyBatch {
        var code: String
        var name: String
        var source: String
        var minimum: Double
        var visible: Bool
        var region: String
        var phone: String
        var status: StudyBatchStatus

        init(code: String, name: String, source: String, minimum: Double, visible: Bool, region: String, phone: String, status: StudyBatchStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.minimum = minimum
            self.visible = visible
            self.region = region
            self.phone = phone
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

        func canMoveTo(_ next: StudyBatchStatus) -> Bool {
            switch status {
            case .requested:
                return next == StudyBatchStatus.granted
            case .granted:
                return next == StudyBatchStatus.revoked || next == StudyBatchStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> StudyBatch {
            return StudyBatch(
                code: code,
                name: name,
                source: source,
                minimum: minimum,
                visible: visible,
                region: region,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study batch in status requested.
    static func newStudyBatch(_ code: String, name: String) -> StudyBatch {
        return StudyBatch(
            code: code,
            name: name,
            source: "",
            minimum: 0.0,
            visible: false,
            region: "",
            phone: "",
            status: StudyBatchStatus.requested
        )
    }
}
