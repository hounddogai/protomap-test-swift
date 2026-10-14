import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves pending care gap notices through their life cycle and keeps a journal of what it did.
    final class PendingCareGapNoticeWorkflow {
        var store: any PendingCareGapNoticeStore
        var validator: PendingCareGapNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCareGapNoticeEngine

        init(store: any PendingCareGapNoticeStore, validator: PendingCareGapNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCareGapNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care gap notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCareGapNoticeStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care gap notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCareGapNoticeStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care gap notice \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newPendingCareGapNoticeWorkflow(_ store: any PendingCareGapNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingCareGapNoticeWorkflow {
        return PendingCareGapNoticeWorkflow(
            store: store,
            validator: defaultPendingCareGapNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCareGapNoticeEngine(flags)
        )
    }
}
