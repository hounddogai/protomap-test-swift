import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff notices through their life cycle and keeps a journal of what it did.
    final class HandoffNoticeService {
        var store: any HandoffNoticeStore
        var validator: HandoffNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffNoticeEngine

        init(store: any HandoffNoticeStore, validator: HandoffNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffNoticeStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffNoticeStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff notice \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newHandoffNoticeService(_ store: any HandoffNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> HandoffNoticeService {
        return HandoffNoticeService(
            store: store,
            validator: defaultHandoffNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffNoticeEngine(flags)
        )
    }
}
