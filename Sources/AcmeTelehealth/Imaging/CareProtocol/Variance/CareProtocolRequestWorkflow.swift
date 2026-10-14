import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol requests through their life cycle and keeps a journal of what it did.
    final class CareProtocolRequestWorkflow {
        var store: any CareProtocolRequestStore
        var validator: CareProtocolRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolRequestStore, validator: CareProtocolRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care protocol request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newCareProtocolRequestWorkflow(_ store: any CareProtocolRequestStore, clock: any Kit.Clocks.Clock) -> CareProtocolRequestWorkflow {
        return CareProtocolRequestWorkflow(
            store: store,
            validator: defaultCareProtocolRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
