import AcmePlatform
import Foundation

extension Labs {
    /// Moves manual result digests through their life cycle and keeps a journal of what it did.
    final class ManualResultDigestService {
        var store: any ManualResultDigestStore
        var validator: ManualResultDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualResultDigestStore, validator: ManualResultDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual result digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualResultDigestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual result digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualResultDigestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualResultDigestService(_ store: any ManualResultDigestStore, clock: any Kit.Clocks.Clock) -> ManualResultDigestService {
        return ManualResultDigestService(
            store: store,
            validator: defaultManualResultDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
