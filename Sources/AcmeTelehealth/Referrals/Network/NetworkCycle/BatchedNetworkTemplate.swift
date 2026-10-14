import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched network template is in its life cycle.
    enum BatchedNetworkTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched network template, with what the planners need to act on it.
    final class BatchedNetworkTemplate {
        var code: String
        var label: String
        var visitMinutes: Int
        var tags: [String]
        var segment: String
        var locale: String
        var ratio: Double
        var status: BatchedNetworkTemplateStatus

        init(code: String, label: String, visitMinutes: Int, tags: [String], segment: String, locale: String, ratio: Double, status: BatchedNetworkTemplateStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.tags = tags
            self.segment = segment
            self.locale = locale
            self.ratio = ratio
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

        func canMoveTo(_ next: BatchedNetworkTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedNetworkTemplateStatus.ready || next == BatchedNetworkTemplateStatus.draining
            case .ready:
                return next == BatchedNetworkTemplateStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedNetworkTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched network template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((ratio - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedNetworkTemplate {
            return BatchedNetworkTemplate(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                tags: tags,
                segment: segment,
                locale: locale,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched network template in status idle.
    static func newBatchedNetworkTemplate(_ code: String, label: String) -> BatchedNetworkTemplate {
        return BatchedNetworkTemplate(
            code: code,
            label: label,
            visitMinutes: 0,
            tags: [],
            segment: "",
            locale: "",
            ratio: 0.0,
            status: BatchedNetworkTemplateStatus.idle
        )
    }
}
