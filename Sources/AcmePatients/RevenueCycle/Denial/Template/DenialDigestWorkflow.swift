import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial digests through their life cycle and keeps a journal of what it did.
    final class DenialDigestDesk {
        var store: any DenialDigestStore
        var validator: DenialDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DenialDigestStore, validator: DenialDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialDigestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialDigestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newDenialDigestDesk(_ store: any DenialDigestStore, clock: any Kit.Clocks.Clock) -> DenialDigestDesk {
        return DenialDigestDesk(store: store, validator: defaultDenialDigestValidator(), clock: clock, journal: [])
    }
}
