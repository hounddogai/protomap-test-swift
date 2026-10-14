import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol bundles through their life cycle and keeps a journal of what it did.
    final class CareProtocolBundleDesk {
        var store: any CareProtocolBundleStore
        var validator: CareProtocolBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolBundleStore, validator: CareProtocolBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolBundleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newCareProtocolBundleDesk(_ store: any CareProtocolBundleStore, clock: any Kit.Clocks.Clock) -> CareProtocolBundleDesk {
        return CareProtocolBundleDesk(
            store: store,
            validator: defaultCareProtocolBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
