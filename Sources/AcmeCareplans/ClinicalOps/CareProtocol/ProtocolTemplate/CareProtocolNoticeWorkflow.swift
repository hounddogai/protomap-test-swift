import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol notices through their life cycle and keeps a journal of what it did.
    final class CareProtocolNoticeWorkflow {
        var store: any CareProtocolNoticeStore
        var validator: CareProtocolNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolNoticeStore, validator: CareProtocolNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolNoticeStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolNoticeStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCareProtocolNoticeWorkflow(_ store: any CareProtocolNoticeStore, clock: any Kit.Clocks.Clock) -> CareProtocolNoticeWorkflow {
        return CareProtocolNoticeWorkflow(
            store: store,
            validator: defaultCareProtocolNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
